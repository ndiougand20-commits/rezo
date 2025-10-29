from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

import crud
import models
import schemas
from database import SessionLocal, engine

# Security
SECRET_KEY = "your-secret-key"  # Change in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def authenticate_user(db: Session, email: str, password: str):
    user = crud.get_user_by_email(db, email=email)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = crud.get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
    return user

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "user": user}

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
