from sqlalchemy.orm import Session # type: ignore
from passlib.context import CryptContext # type: ignore
import models
import schemas

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password,
        user_type=user.user_type,
        first_name=user.first_name,
        last_name=user.last_name,
    )
    db.add(db_user)
    db.commit() # Commit to get the user ID
    db.refresh(db_user)

    # Create the associated profile based on user_type
    if user.user_type == models.UserType.STUDENT:
        db_profile = models.Student(user_id=db_user.id)
    elif user.user_type == models.UserType.HIGH_SCHOOL:
        db_profile = models.HighSchooler(user_id=db_user.id)
    elif user.user_type == models.UserType.COMPANY:
        db_profile = models.Company(user_id=db_user.id)
    elif user.user_type == models.UserType.UNIVERSITY:
        db_profile = models.University(user_id=db_user.id)
    else:
        # Handle unknown user type if necessary
        db_profile = None

    if db_profile:
        db.add(db_profile)
        db.commit()
        db.refresh(db_profile)

    return db_user

def create_student(db: Session, student: schemas.StudentCreate):
    db_student = models.Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

def get_student(db: Session, student_id: int):
    return db.query(models.Student).filter(models.Student.id == student_id).first()

def get_student_by_user_id(db: Session, user_id: int):
    return db.query(models.Student).filter(models.Student.user_id == user_id).first()

def create_high_schooler(db: Session, high_schooler: schemas.HighSchoolerCreate):
    db_high_schooler = models.HighSchooler(**high_schooler.dict())
    db.add(db_high_schooler)
    db.commit()
    db.refresh(db_high_schooler)
    return db_high_schooler

def get_high_schooler(db: Session, high_schooler_id: int):
    return db.query(models.HighSchooler).filter(models.HighSchooler.id == high_schooler_id).first()

def get_high_schooler_by_user_id(db: Session, user_id: int):
    return db.query(models.HighSchooler).filter(models.HighSchooler.user_id == user_id).first()

def create_company(db: Session, company: schemas.CompanyCreate):
    db_company = models.Company(**company.dict())
    db.add(db_company)
    db.commit()
    db.refresh(db_company)
    return db_company

def get_company(db: Session, company_id: int):
    return db.query(models.Company).filter(models.Company.id == company_id).first()

def get_company_by_user_id(db: Session, user_id: int):
    return db.query(models.Company).filter(models.Company.user_id == user_id).first()

def create_university(db: Session, university: schemas.UniversityCreate):
    db_university = models.University(**university.dict())
    db.add(db_university)
    db.commit()
    db.refresh(db_university)
    return db_university

def get_university(db: Session, university_id: int):
    return db.query(models.University).filter(models.University.id == university_id).first()

def get_university_by_user_id(db: Session, user_id: int):
    return db.query(models.University).filter(models.University.user_id == user_id).first()

def create_company_offer(db: Session, offer: schemas.OfferCreate, company_id: int):
    db_offer = models.Offer(**offer.dict(), company_id=company_id)
    db.add(db_offer)
    db.commit()
    db.refresh(db_offer)
    return db_offer

def get_offers(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Offer).offset(skip).limit(limit).all()

def create_university_formation(db: Session, formation: schemas.FormationCreate, university_id: int):
    db_formation = models.Formation(**formation.dict(), university_id=university_id)
    db.add(db_formation)
    db.commit()
    db.refresh(db_formation)
    return db_formation

def get_formations(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Formation).offset(skip).limit(limit).all()