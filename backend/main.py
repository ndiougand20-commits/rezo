from fastapi import FastAPI, Depends, HTTPException, status # type: ignore
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm # type: ignore
from sqlalchemy.orm import Session # type: ignore
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt # type: ignore

import crud
import models
import schemas
from database import SessionLocal, engine, get_db

# Security
SECRET_KEY = "your-secret-key"  # Change in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
pwd_context = crud.pwd_context

def authenticate_user(db: Session, email: str, password: str):
    user = crud.get_user_by_email(db, email=email)
    if not user:
        return False
    if not pwd_context.verify(password, user.hashed_password):
        return False
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
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
    if user.password != user.password_confirm:
        raise HTTPException(status_code=400, detail="Passwords do not match")
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.get("/students/user/{user_id}", response_model=schemas.Student)
def read_student_by_user_id(user_id: int, db: Session = Depends(get_db)):
    db_student = crud.get_student_by_user_id(db, user_id=user_id)
    if db_student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return db_student

@app.get("/high_schoolers/user/{user_id}", response_model=schemas.HighSchooler)
def read_high_schooler_by_user_id(user_id: int, db: Session = Depends(get_db)):
    db_high_schooler = crud.get_high_schooler_by_user_id(db, user_id=user_id)
    if db_high_schooler is None:
        raise HTTPException(status_code=404, detail="High schooler not found")
    return db_high_schooler

@app.get("/companies/user/{user_id}", response_model=schemas.Company)
def read_company_by_user_id(user_id: int, db: Session = Depends(get_db)):
    db_company = crud.get_company_by_user_id(db, user_id=user_id)
    if db_company is None:
        raise HTTPException(status_code=404, detail="Company not found")
    return db_company

@app.get("/universities/user/{user_id}", response_model=schemas.University)
def read_university_by_user_id(user_id: int, db: Session = Depends(get_db)):
    db_university = crud.get_university_by_user_id(db, user_id=user_id)
    if db_university is None:
        raise HTTPException(status_code=404, detail="University not found")
    return db_university

@app.get("/")
def read_root():
    return {"Hello": "World"}

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

# Conversations and Messages
@app.post("/conversations/", response_model=schemas.Conversation)
def create_conversation(conversation: schemas.ConversationCreate, db: Session = Depends(get_db)):
    return crud.create_conversation(db=db, conversation=conversation)

@app.get("/conversations/{conversation_id}", response_model=schemas.Conversation)
def read_conversation(conversation_id: int, db: Session = Depends(get_db)):
    db_conversation = crud.get_conversation(db, conversation_id=conversation_id)
    if db_conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return db_conversation

@app.get("/users/{user_id}/conversations/", response_model=list[schemas.Conversation])
def read_conversations_for_user(user_id: int, db: Session = Depends(get_db)):
    conversations = crud.get_conversations_for_user(db, user_id=user_id)
    return conversations

@app.post("/messages/", response_model=schemas.Message)
def create_message(message: schemas.MessageCreate, db: Session = Depends(get_db)):
    return crud.create_message(db=db, message=message)

@app.get("/conversations/{conversation_id}/messages/", response_model=list[schemas.Message])
def read_messages_for_conversation(conversation_id: int, db: Session = Depends(get_db)):
    messages = crud.get_messages_for_conversation(db, conversation_id=conversation_id)
    return messages
