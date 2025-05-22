package com.ssafy.ollana.user.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.util.List;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "users") // postgreSQL 예약어로 인해 users로 설정
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Integer id;

    @Column(unique = true, nullable = false, length = 50)
    private String email;

    @Column
    private String password;

    @Column(unique = true, nullable = false, length = 10)
    private String nickname;

    @Column(nullable = false, length = 10)
    private String birth;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Gender gender;

    @Column(nullable = false, columnDefinition = "double precision default 0.0")
    @Builder.Default
    private double totalDistance = 0.0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, columnDefinition = "varchar(8) default 'SEED'")
    @Builder.Default
    private Grade grade = Grade.SEED;

    @Column(nullable = false, columnDefinition = "integer default 0")
    @Builder.Default
    private int exp = 0;

    @Column(nullable = false, columnDefinition = "integer default 0")
    @Builder.Default
    private int gradeCount = 0;

    @Column(nullable = false)
    private String profileImage;

    @Column
    private Long kakaoId;

    @OneToMany(mappedBy = "user", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<HikingLiveRecords> hikingLiveRecords;

    @OneToMany(mappedBy = "user", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<BattleHistory> battleHistories;

    @OneToMany(mappedBy = "opponent", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<BattleHistory> opponentBattleHistories;

    @OneToMany(mappedBy = "user", cascade = CascadeType.REMOVE, orphanRemoval = true)
    private List<Footprint> footprints;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private boolean isSurvey = false;

    @Column(nullable = false, columnDefinition = "boolean default false")
    @Builder.Default
    private boolean isSocial = false;

    @Column(nullable = false, columnDefinition = "boolean default true")
    @Builder.Default
    private boolean isAgree = true;

    @Column(nullable = false, columnDefinition = "boolean default false")
    @Builder.Default
    private boolean isTempPassword = false;

    // exp 증가 및 그에 따른 grade 업데이트
    public void addExp(int exp) {
        this.exp += exp;

        if (this.exp >= Grade.getMaxExp()) {
            this.gradeCount++;
            this.exp = this.exp - Grade.getMaxExp();
        }

        this.grade = Grade.getGrade(this.exp);
    }

    // 총 등산 거리 업데이트
    public void addTotalDistance(double distance) {
        this.totalDistance += distance;
    }
}
