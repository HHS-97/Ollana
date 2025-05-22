import json
import pickle
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone

import sys
import numpy as np
import pandas as pd
import requests
from scipy import cluster
import uvicorn
from fastapi import Depends, FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Body
from pydantic import BaseModel
from sqlalchemy.orm import Session

from methods import method
from models.models import UserProfile
from models.database import init_db, SessionLocal

import tensorflow as tf
import joblib
import logging
from typing import Dict, Any

# 로그 기본 설정
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),  # 콘솔 로그
    ]
)

logger = logging.getLogger(__name__)

# K_MEANS_DATA_ROADED
k_means_df = pd.read_csv("./datas/K_means/clustered_mountains.csv")
scaler = None
kmeans = None 
pace_scaler = None
intensity_model = None
mountain_data = None
###############입력데이터 모델 정리하는 곳
class UserInput(BaseModel):
    theme: str
    experience: str
    region: str

###############DB 세션 의존성 정의
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()




#########################################
###
###############시작시 활동 정리하는 곳
@asynccontextmanager
async def lifespan(app: FastAPI):
    global scaler, kmeans, pace_scaler, intensity_model, mountain_data

    try:
        # 클러스터링용
        with open("./datas/K_means/scaler.pkl", "rb") as f:
            scaler = pickle.load(f)
        with open("./datas/K_means/kmeans_model.pkl", "rb") as f:
            kmeans = pickle.load(f)

        # 회귀 모델용
        pace_scaler = joblib.load("./datas/pace_model/intensity_scaler.pkl")
        intensity_model = tf.keras.models.load_model("./datas/pace_model/intensity_model.keras")
        mountain_data = pd.read_csv("./datas/mountains/mountain_202505151648.csv", encoding="UTF-8")
        # 모든 객체 로드 확인
        if None in [scaler, kmeans, pace_scaler, intensity_model]:
            raise ValueError("❌ 모델 또는 스케일러 로드 실패")

        logger.info("✅ 모든 모델 및 스케일러 정상 로드 완료")
        init_db()
        yield

    except Exception as e:
        logger.exception(f"🔥 초기화 중 오류 발생: {e}")
        sys.exit(1)  # FastAPI 실행 중단



#########################################
app = FastAPI(lifespan=lifespan)


# 등산지수 API
@app.post("/weather")
async def weather():
    lat, lon = 37.5665, 126.9780
    API_KEY = "052b29e73d62b1df3cac886dbc3641a0"

    WEATHER_URL = f"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&units=metric&appid={API_KEY}"
    DUST_URL = f"https://api.openweathermap.org/data/2.5/air_pollution?lat={lat}&lon={lon}&appid={API_KEY}"

    weather_data = requests.get(WEATHER_URL).json()
    dust_data = requests.get(DUST_URL).json()

    pm10 = dust_data["list"][0]["components"]["pm10"]
    pm25 = dust_data["list"][0]["components"]["pm2_5"]

    now_kst = datetime.now(timezone.utc) + timedelta(hours=9)
    today_str = now_kst.date().isoformat()

    results = []

    for item in weather_data["list"]:
        # UTC → KST 변환
        dt_kst = datetime.fromisoformat(item["dt_txt"]) + timedelta(hours=9)
        if dt_kst.date().isoformat() != today_str:
            continue

        temp = item["main"]["feels_like"]
        wind = item["wind"]["speed"]
        humidity = item["main"]["humidity"]
        cloud = item["clouds"]["all"]

        score, desc = method.interpret_weather(temp, wind, humidity, cloud, pm10, pm25)

        results.append({
            "time": dt_kst.strftime("%Y-%m-%d %H:%M"),
            "score": score,
            **desc
        })

    return JSONResponse(content={"today_weather": results})

# 유저 설문 제출 API
@app.post("/submit_survey/{user_id}")
async def submit_suervey(user_id: str, user_input:UserInput, db:Session = Depends(get_db)):
    if not user_id:
        return JSONResponse(status_code=400, content={"message": "유효한 user_id를 query 파라미터로 전달해주세요."})
    
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if user:
        user.theme = user_input.theme
        user.experience = user_input.experience
        user.region = user_input.region
    else:
        user = UserProfile(
            user_id=user_id,
            theme=user_input.theme,
            experience=user_input.experience,
            region=user_input.region
        )
        db.add(user)
        db.flush()
        
    db.commit()
    return JSONResponse({"message": "설문이 성공적으로 저장되었습니다."})
    
@app.get("/has_survey/{user_id}")
async def has_survey(user_id: str, db: Session = Depends(get_db)):
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    return {"has_survey": bool(user)}


# 유저 설문 기반 추천(클러스터링)
@app.post("/recommend/{user_id}")
async def recommend(user_id:str, db: Session = Depends(get_db)):
    # 설문데이터 sqlite에서 찾기
    global mountain_data
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if not user:
        return JSONResponse(
            status_code=400,
            content={"message": "설문을 먼저 생성하세요."}
        )
    
    user_input = UserInput(
        theme=user.theme,
        experience=user.experience,
        region=user.region
    )
    
    # 유저의 백터 검색
    user_vector = method.make_user_vector(user_input.model_dump(), scaler)
    scaled_vec = scaler.transform(user_vector)
    cluster_label = kmeans.predict(scaled_vec)[0]

    matched = k_means_df[k_means_df["cluster"] == cluster_label]
    # 이름과 설명을 찾기
    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")

    # 이미지 URL 찾기
    for rec_data in recommendations:
        rec_data["image_url"] = method.get_image_by_mountain_name(rec_data["mountain_name"])
        matched = mountain_data[mountain_data["mountain_name"] == rec_data["mountain_name"]]
        if not matched.empty:
            info = matched.iloc[0]
            rec_data["location"] = info.get("mountain_loc")
            rec_data["level"] = info.get("level")
            rec_data["height"] = info.get("mountain_height")

    return JSONResponse({
        "cluster": int(cluster_label),
        "recommendations": recommendations
    })

# 키워드 기반 검색 API
@app.post("/recommend_by_keyword")
async def recommend_by_keyword(keyword: str = Body(..., embed=True)):
    # 사용자가 입력한 키워드
    global mountain_data

    theme_col = f"has_{keyword}"

    # 키워드 검사
    if theme_col not in k_means_df.columns:
        return JSONResponse(
            status_code=400,
            content={"message": f"유효하지 않은 키워드입니다: {keyword}"}
        )

    # 키워드 추출
    matched = k_means_df[k_means_df[theme_col] > 0]

    # 비었는지 체크
    if matched.empty:
        return JSONResponse(
            status_code=404,
            content={"message": f"'{keyword}' 키워드를 포함한 산을 찾을 수 없습니다."}
        )

    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")

    for rec_data in recommendations:
        image_url = method.get_image_by_mountain_name(rec_data["mountain_name"])
        rec_data["image_url"] = image_url or "https://image.ytn.co.kr/general/jpg/2020/0924/202009241540389154_d.jpg"
        matched = mountain_data[mountain_data["mountain_name"] == rec_data["mountain_name"]]
        if not matched.empty:
            info = matched.iloc[0]
            rec_data["location"] = info.get("mountain_loc")
            rec_data["level"] = info.get("level")
            rec_data["height"] = info.get("mountain_height")
    return JSONResponse({
        "keyword": keyword,
        "recommendations": recommendations
    })

# 지역 기반 검색 API
@app.post("/recommend_by_region")
async def recommend_by_region(region: str = Body(..., embed=True)):
    matched = k_means_df[k_means_df["region"] == region]
    global mountain_data

    if matched.empty:
        return JSONResponse(
            status_code=404,
            content={"message": f"'{region}' 지역의 산 정보를 찾을 수 없습니다."}
        )
    
    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")
    
    for rec_data in recommendations:
        image_url = method.get_image_by_mountain_name(rec_data["mountain_name"])
        rec_data["image_url"] = image_url or "https://image.ytn.co.kr/general/jpg/2020/0924/202009241540389154_d.jpg"
        matched = mountain_data[mountain_data["mountain_name"] == rec_data["mountain_name"]]
        if not matched.empty:
            info = matched.iloc[0]
            rec_data["location"] = info.get("mountain_loc")
            rec_data["level"] = info.get("level")
            rec_data["height"] = info.get("mountain_height")
            
    return JSONResponse({
        "region": region,
        "recommendations": recommendations
    })

# distance = 미터 / time = 초 / altitude = 고도
@app.post("/data_collection")
async def data_collection(data: Dict[str, Any]):
    logger.info(f"📥 생체 데이터 수신: {data}")
    required_keys = {"heartRate", "speed", "time", "altitude"}
    
    if not required_keys.issubset(data):
        logger.warning("❌ 누락된 필수 데이터가 존재함")
        return JSONResponse(status_code=400, content={"message": "필수 데이터 누락"})

    try:
        # ▶ 입력 전처리
        heart_rate = data["heartRate"]
        variation = 12.0  # 향후 개선 가능
        max_hr = heart_rate + 25
        min_hr = heart_rate - 20
        delta = max_hr - min_hr
        range_ratio = round(delta / max_hr, 4)

        # ▶ 모델 예측
        input_vec = np.array([[heart_rate, variation, max_hr, range_ratio]])
        input_scaled = pace_scaler.transform(input_vec)
        predicted_score = float(intensity_model.predict(input_scaled)[0][0])
        predicted_score = round(predicted_score, 2)

        # ▶ 보조 지표 정규화
        norm_speed = round(min(data["speed"] / 5.0, 1.0), 2)
        time_score = data["time"] * (20 / 180)
        altitude_score = data["altitude"] * 0.1

        # ▶ 최종 점수 계산
        intensity_score = (predicted_score / 2.0) * 40
        final_score = round(norm_speed + time_score + altitude_score + intensity_score, 1)


        # ▶ 강도 레벨 및 메시지 생성
        if final_score < 49:
            level = "저강도"
            message = "천천히 풍경을 보며 산행을 즐기고 계시는군요."
        elif final_score < 79:
            level = "중강도"
            message = "좋은 페이스로 산행 중입니다."
        else:
            level = "고강도"
            message = "고강도 산행을 하고 계십니다!"

        logger.info(f"✅ 예측 강도: {predicted_score}, 최종 점수: {final_score}, 레벨: {level}")

        return {
            "score": final_score,
            "level": level,
            "message": message
        }

    except Exception as e:
        logger.exception("❌ 예측 처리 중 오류 발생")
        return JSONResponse(status_code=500, content={"message": "서버 내부 오류", "error": str(e)})

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
