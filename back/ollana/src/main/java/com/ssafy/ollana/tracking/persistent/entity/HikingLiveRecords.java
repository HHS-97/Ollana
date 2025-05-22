package com.ssafy.ollana.tracking.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

@Getter
@Entity
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
public class HikingLiveRecords extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "hiking_seq")
    @SequenceGenerator(
            name = "hiking_seq",
            sequenceName = "hiking_live_records_seq",
            allocationSize = 100
    )
    @Column(name = "hiking_live_records_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mountain_id")
    private Mountain mountain;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "path_id")
    private Path path;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hiking_history_id")
    private HikingHistory hikingHistory;

    private int totalTime;
    private double totalDistance;
    private Double latitude;
    private Double longitude;
    private Integer heartRate;
}
