from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session

import crud
import models
import schemas
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.get("/")
def read_root():
    return {"Hello": "World"}

# Students
@app.post("/students/", response_model=schemas.Student)
def create_student(student: schemas.StudentCreate, db: Session = Depends(get_db)):
    return crud.create_student(db=db, student=student)

@app.get("/students/{student_id}", response_model=schemas.Student)
def read_student(student_id: int, db: Session = Depends(get_db)):
    db_student = crud.get_student(db, student_id=student_id)
    if db_student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return db_student

# High Schoolers
@app.post("/high_schoolers/", response_model=schemas.HighSchooler)
def create_high_schooler(high_schooler: schemas.HighSchoolerCreate, db: Session = Depends(get_db)):
    return crud.create_high_schooler(db=db, high_schooler=high_schooler)

@app.get("/high_schoolers/{high_schooler_id}", response_model=schemas.HighSchooler)
def read_high_schooler(high_schooler_id: int, db: Session = Depends(get_db)):
    db_high_schooler = crud.get_high_schooler(db, high_schooler_id=high_schooler_id)
    if db_high_schooler is None:
        raise HTTPException(status_code=404, detail="High schooler not found")
    return db_high_schooler

# Companies
@app.post("/companies/", response_model=schemas.Company)
def create_company(company: schemas.CompanyCreate, db: Session = Depends(get_db)):
    return crud.create_company(db=db, company=company)

@app.get("/companies/{company_id}", response_model=schemas.Company)
def read_company(company_id: int, db: Session = Depends(get_db)):
    db_company = crud.get_company(db, company_id=company_id)
    if db_company is None:
        raise HTTPException(status_code=404, detail="Company not found")
    return db_company

# Universities
@app.post("/universities/", response_model=schemas.University)
def create_university(university: schemas.UniversityCreate, db: Session = Depends(get_db)):
    return crud.create_university(db=db, university=university)

@app.get("/universities/{university_id}", response_model=schemas.University)
def read_university(university_id: int, db: Session = Depends(get_db)):
    db_university = crud.get_university(db, university_id=university_id)
    if db_university is None:
        raise HTTPException(status_code=404, detail="University not found")
    return db_university

# Offers
@app.post("/companies/{company_id}/offers/", response_model=schemas.Offer)
def create_offer_for_company(
    company_id: int, offer: schemas.OfferCreate, db: Session = Depends(get_db)
):
    return crud.create_company_offer(db=db, offer=offer, company_id=company_id)

@app.get("/offers/", response_model=list[schemas.Offer])
def read_offers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    offers = crud.get_offers(db, skip=skip, limit=limit)
    return offers

# Formations
@app.post("/universities/{university_id}/formations/", response_model=schemas.Formation)
def create_formation_for_university(
    university_id: int, formation: schemas.FormationCreate, db: Session = Depends(get_db)
):
    return crud.create_university_formation(db=db, formation=formation, university_id=university_id)

@app.get("/formations/", response_model=list[schemas.Formation])
def read_formations(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    formations = crud.get_formations(db, skip=skip, limit=limit)
    return formations
