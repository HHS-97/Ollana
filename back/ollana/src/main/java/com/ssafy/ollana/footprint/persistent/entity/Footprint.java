package com.ssafy.ollana.footprint.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Getter
@Builder
@Entity
@Table(
		name = "footprint",
		indexes = {
				@Index(name = "idx_footprint_user_mountain", columnList = "user_id, mountain_id")
		}
)
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Footprint extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "footprint_id")
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id")
	private User user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "mountain_id")
	private Mountain mountain;

	@OneToMany(mappedBy = "footprint", cascade = CascadeType.REMOVE, orphanRemoval = true)
	private List<HikingHistory> hikingHistories;

	public static Footprint of(User user, Mountain mountain) {
		return Footprint.builder()
				.user(user)
				.mountain(mountain)
				.build();
	}

}

