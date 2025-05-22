from sqlalchemy import Column, String
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
class UserProfile(Base):
    __tablename__ = "user_profile"
    
    user_id = Column(String, primary_key=True)
    theme = Column(String, nullable=False)
    experience = Column(String, nullable=False)
    region = Column(String, nullable=False)