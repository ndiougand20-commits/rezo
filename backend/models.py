from sqlalchemy import Boolean, Column, Integer, String, Enum, ForeignKey, DateTime
from sqlalchemy.orm import relationship # type: ignore
from sqlalchemy.sql import func
from database import Base
import enum

class UserType(str, enum.Enum):
    STUDENT = "student"
    HIGH_SCHOOL = "high_school"
    COMPANY = "company"
    UNIVERSITY = "university"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    user_type = Column(Enum(UserType))
    first_name = Column(String)
    last_name = Column(String)
    device_token = Column(String, nullable=True)

class Student(Base):
    __tablename__ = "students"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User")

class HighSchooler(Base):
    __tablename__ = "high_schoolers"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User")

class Company(Base):
    __tablename__ = "companies"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User")
    offers = relationship("Offer", back_populates="company")

class University(Base):
    __tablename__ = "universities"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User")
    formations = relationship("Formation", back_populates="university")

class Offer(Base):
    __tablename__ = "offers"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    company_id = Column(Integer, ForeignKey("companies.id"))

    company = relationship("Company", back_populates="offers")

class Formation(Base):
    __tablename__ = "formations"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    university_id = Column(Integer, ForeignKey("universities.id"))

    university = relationship("University", back_populates="formations")

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True, index=True)
    participant1_id = Column(Integer, ForeignKey("users.id"))
    participant2_id = Column(Integer, ForeignKey("users.id"))

    participant1 = relationship("User", foreign_keys=[participant1_id])
    participant2 = relationship("User", foreign_keys=[participant2_id])
    messages = relationship("Message", back_populates="conversation")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    content = Column(String)
    sender_id = Column(Integer, ForeignKey("users.id"))
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    timestamp = Column(String)  # Pour simplifier, on utilise une string pour le timestamp

    sender = relationship("User")
    conversation = relationship("Conversation", back_populates="messages")

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Qui a fait l'action de swiper
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Sur quoi l'action a été faite (une seule des deux sera remplie)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=True)
    formation_id = Column(Integer, ForeignKey("formations.id"), nullable=True)

    # Relation pour accéder à l'utilisateur depuis un match
    user = relationship("User")
    offer = relationship("Offer")
    formation = relationship("Formation")
