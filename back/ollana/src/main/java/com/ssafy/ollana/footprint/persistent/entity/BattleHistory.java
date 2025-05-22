package com.ssafy.ollana.footprint.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleResult;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Getter
@Builder
@Entity
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class BattleHistory extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "battle_history_id")
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "mountain_id")
	private Mountain mountain;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "path_id")
	private Path path;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id")
	@OnDelete(action = OnDeleteAction.CASCADE)
	private User user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "opponent_id")
	@OnDelete(action = OnDeleteAction.CASCADE)
	private User opponent;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private BattleResult result;
}
