#### 데이터 로드
import os
import pickle

import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))  # methods 디렉토리
DATA_DIR = os.path.join(BASE_DIR, "..", "datas", "mountains")

mountain_origin = pd.read_csv(os.path.join(DATA_DIR, "mountain_202505151648.csv"), encoding="UTF-8")
mountain_img = pd.read_csv(os.path.join(DATA_DIR, "mountain_img_202505151642.csv"))

###########################################################################################################
#1. 등산지수를 보여주는 알고리즘
def interpret_weather(temp, wind, humidity, cloud, pm10, pm25):
    # 체감온도
    if 12 < temp < 22:
        temp_score = 100
        temp_desc = "보통"
    else:
        temp_score = max(0, 100 - abs(temp - 17) * 5)
        temp_desc = "낮음" if temp < 12 else "높음"

    # 풍속
    if wind <= 3:
        wind_score = 100
        wind_desc = "좋음"
    elif wind >= 6:
        wind_score = 50
        wind_desc = "나쁨"
    else:
        wind_score = 100 - (wind - 3) * 15
        wind_desc = "보통"

    # 습도
    if 40 <= humidity <= 60:
        hum_score = 100
        hum_desc = "좋음"
    else:
        hum_score = max(0, 100 - abs(humidity - 50) * 2)
        hum_desc = "나쁨"

    # 구름
    if 20 <= cloud <= 50:
        cloud_score = 100
        cloud_desc = "적절"
    else:
        cloud_score = max(40, 100 - abs(cloud - 35) * 3)
        cloud_desc = "많음" if cloud > 50 else "적음"

    # PM10
    if pm10 <= 30:
        pm10_score = 100
        pm10_desc = "좋음"
    elif pm10 <= 80:
        pm10_score = 60
        pm10_desc = "보통"
    else:
        pm10_score = 30
        pm10_desc = "나쁨"

    # PM2.5
    if pm25 <= 15:
        pm25_score = 100
        pm25_desc = "좋음"
    elif pm25 <= 35:
        pm25_score = 70
        pm25_desc = "보통"
    else:
        pm25_score = 40
        pm25_desc = "나쁨"

    total_score = (
        temp_score * 0.25 +
        wind_score * 0.15 +
        hum_score * 0.15 +
        cloud_score * 0.10 +
        pm10_score * 0.2 +
        pm25_score * 0.15
    )

    return round(total_score, 1), {
        "체감온도": f"{temp:.1f}℃ ({temp_desc})",
        "풍속": f"{wind:.1f}m/s ({wind_desc})",
        "습도": f"{humidity}% ({hum_desc})",
        "구름": f"{cloud}% ({cloud_desc})",
        "미세먼지": f"{pm10}μg/m³ ({pm10_desc})",
        "초미세먼지": f"{pm25}μg/m³ ({pm25_desc})"
    }

###########################################################################################################
#2. 유저 맞춤 산을 추천해주는 알고리즘
def make_user_vector(user_input, scaler):
    feature_cols = list(scaler.feature_names_in_)
    vec = {col: 0 for col in feature_cols}

    # 등산 난이도 → 고도 맵핑
    exp_map = {"초급": 500, "중급": 850, "고급": 1200}
    vec["mountain_height"] = exp_map.get(user_input["experience"], 850)

    # 지역 위경도 매핑
    region_coords = {
        "서울": (37.5, 127.0),
        "강원": (37.8, 128.2),
        "경기": (37.3, 127.2),
        "충청": (36.5, 127.5),
        "경상": (35.8, 128.6),
        "전라": (35.5, 127.0),
        "제주": (33.4, 126.5),
    }
    lat, lon = region_coords.get(user_input["region"], (36.5, 127.5))  # default: 충청
    vec["mountain_latitude"] = lat
    vec["mountain_longitude"] = lon

    # 테마 키워드
    theme_map = {
        "계곡": ["has_계곡"],
        "바위": ["has_바위"],
        "풍경": ["has_아름다운"],
        "숲": ["has_울창한", "has_깊은"],
        "단풍": ["has_단풍"]
    }
    for col in theme_map.get(user_input["theme"], []):
        if col in vec:
            vec[col] = 1

    # 지역 one-hot 인코딩도 함께 반영
    region_col = f"region_{user_input['region']}"
    if region_col in vec:
        vec[region_col] = 1

    user_df = pd.DataFrame([vec])
    user_df = user_df.reindex(columns=feature_cols, fill_value=0)
    return user_df

###########################################################################################################
#3. 이름 넣으면 이미지를 가져오는 메서드
def get_image_by_mountain_name(mountain_name:str):
    # 산 이름으로 아이디 찾기
    mountain_name_clean = mountain_name.strip()

    row = mountain_origin[mountain_origin["mountain_name"].str.strip() == mountain_name_clean]
    if row.empty:
        return None
    # 아이디 추출
    mountain_id = row["mountain_id"].values[0]
    
    # 아이디로 이미지 URL 가져오기
    img_raw = mountain_img[mountain_img["mountain_id"] == mountain_id]
    if img_raw.empty:
        return None
    
    # 이미지 url
    return img_raw["mountain_img_url"].values[0]