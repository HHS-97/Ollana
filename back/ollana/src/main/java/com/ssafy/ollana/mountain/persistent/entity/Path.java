package com.ssafy.ollana.mountain.persistent.entity;

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
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.Point;

@Getter
@Entity
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
public class Path {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "path_id")
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "mountain_id")
	private Mountain mountain;

	private String pathName;

	private Double pathLength;

	@Column(columnDefinition = "geometry(Point, 4326)")
	private Point centerPoint;

	@Column(columnDefinition = "geometry(LineString, 4326)")
	private LineString route;

	@Enumerated(EnumType.STRING)
	private Level level;

	private String pathTime;
}

