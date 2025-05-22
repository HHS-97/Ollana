package com.ssafy.ollana.footprint.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Getter
@Builder
@Entity
@Table(
		name = "hiking_history",
		indexes = {
				@Index(name = "idx_history_footprint_path", columnList = "footprint_id, path_id")
		}
)
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class HikingHistory extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "hiking_history_id")
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "path_id")
	private Path path;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "footprint_id")
	private Footprint footprint;

	private int hikingTime;
	private double averageHeartRate;
	private int maxHeartRate;

	@OneToMany(mappedBy = "hikingHistory", cascade = CascadeType.REMOVE, orphanRemoval = true)
	private List<HikingLiveRecords> hikingLiveRecords;

	public static HikingHistory of(Footprint footprint, Path path, int hikingTime, List<Integer> heartRates) {
		double avg = heartRates.stream().mapToInt(i -> i).average().orElse(0);
		int max = heartRates.stream().mapToInt(i -> i).max().orElse(0);

		return HikingHistory.builder()
				.footprint(footprint)
				.path(path)
				.hikingTime(hikingTime)
				.averageHeartRate(avg)
				.maxHeartRate(max)
				.build();
	}
}
