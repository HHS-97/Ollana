package com.ssafy.ollana.mountain.persistent.entity;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

import java.util.List;

@Getter
@Entity
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
public class Mountain {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "mountain_id")
	private Integer id;

	@Column(unique = true)
	private String mntnCode;

	@Column(columnDefinition = "geometry(Point, 4326)")
	private Point geom;  // PostGIS 전용 geometry 컬럼

	private String mountainName;
	private String mountainLoc;
	private double mountainHeight;

	@Column(columnDefinition = "TEXT")
	private String mountainDescription;

	@Enumerated(EnumType.STRING)
	private Level level;

	private double mountainLatitude;
	private double mountainLongitude;

	private String mountainBadge;

	@OneToMany(mappedBy = "mountain", fetch = FetchType.LAZY)
	private List<MountainImg> mountainImgs;
}
