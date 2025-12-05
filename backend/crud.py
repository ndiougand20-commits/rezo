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

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    update_data = user_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_user, key, value)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user_device_token(db: Session, user_id: int, token: str):
    db_user = get_user(db, user_id)
    if db_user:
        db_user.device_token = token
        db.commit()
        db.refresh(db_user)
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

def update_student_profile(db: Session, user_id: int, profile_data: schemas.StudentUpdate):
    db_profile = get_student_by_user_id(db, user_id)
    if not db_profile:
        return None
    update_data = profile_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_profile, key, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile

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

def update_high_schooler_profile(db: Session, user_id: int, profile_data: schemas.HighSchoolerUpdate):
    db_profile = get_high_schooler_by_user_id(db, user_id)
    if not db_profile:
        return None
    update_data = profile_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_profile, key, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile

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

def update_company_profile(db: Session, user_id: int, profile_data: schemas.CompanyUpdate):
    db_profile = get_company_by_user_id(db, user_id)
    if not db_profile:
        return None
    update_data = profile_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_profile, key, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile

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

def update_university_profile(db: Session, user_id: int, profile_data: schemas.UniversityUpdate):
    db_profile = get_university_by_user_id(db, user_id)
    if not db_profile:
        return None
    update_data = profile_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_profile, key, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile

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

def create_conversation(db: Session, conversation: schemas.ConversationCreate):
    db_conversation = models.Conversation(**conversation.dict())
    db.add(db_conversation)
    db.commit()
    db.refresh(db_conversation)
    return db_conversation

def get_conversation(db: Session, conversation_id: int):
    return db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()

def get_conversations_for_user(db: Session, user_id: int):
    # Récupère toutes les conversations de l'utilisateur
    conversations = db.query(models.Conversation).filter(
        (models.Conversation.participant1_id == user_id) | (models.Conversation.participant2_id == user_id)
    ).all()

    detailed_conversations = []
    for conv in conversations:
        # Détermine qui est l'autre participant
        other_participant_user = conv.participant2 if conv.participant1_id == user_id else conv.participant1
        
        # Récupère le dernier message de la conversation
        last_message = db.query(models.Message).filter(models.Message.conversation_id == conv.id).order_by(models.Message.timestamp.desc()).first()

        detailed_conversations.append(schemas.ConversationDetail(
            id=conv.id,
            other_participant=other_participant_user,
            last_message=last_message
        ))
    return detailed_conversations

def get_conversation_between_users(db: Session, user1_id: int, user2_id: int):
    return db.query(models.Conversation).filter(
        ((models.Conversation.participant1_id == user1_id) & (models.Conversation.participant2_id == user2_id)) |
        ((models.Conversation.participant1_id == user2_id) & (models.Conversation.participant2_id == user1_id))
    ).first()


def create_message(db: Session, message: schemas.MessageCreate):
    db_message = models.Message(**message.dict())
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message

def get_messages_for_conversation(db: Session, conversation_id: int):
    return db.query(models.Message).filter(models.Message.conversation_id == conversation_id).order_by(models.Message.timestamp).all()

def create_match(db: Session, match_data: schemas.MatchCreate):
    """
    Enregistre un "like" d'un utilisateur sur une offre ou une formation.
    Si c'est une candidature (étudiant -> offre) ou un intérêt (lycéen -> formation),
    crée une conversation si elle n'existe pas déjà.
    """
    db_match = models.Match(
        user_id=match_data.user_id,
        offer_id=match_data.offer_id,
        formation_id=match_data.formation_id
    )
    db.add(db_match)
    db.commit()
    db.refresh(db_match)

    participant1_id = match_data.user_id
    participant2_id = None

    # Cas d'une candidature à une offre
    if match_data.offer_id:
        offer = db.query(models.Offer).filter(models.Offer.id == match_data.offer_id).first()
        if offer and offer.company:
            participant2_id = offer.company.user_id

    # Cas d'un intérêt pour une formation
    elif match_data.formation_id:
        formation = db.query(models.Formation).filter(models.Formation.id == match_data.formation_id).first()
        if formation and formation.university:
            participant2_id = formation.university.user_id

    if participant1_id and participant2_id:
        # Vérifier si une conversation existe déjà
        existing_conversation = get_conversation_between_users(db, participant1_id, participant2_id)
        if existing_conversation:
            return {"match": db_match, "is_new_conversation": False, "conversation_id": existing_conversation.id}
        else:
            # Créer une nouvelle conversation
            new_conversation_data = schemas.ConversationCreate(participant1_id=participant1_id, participant2_id=participant2_id)
            new_conversation = create_conversation(db, new_conversation_data)
            # TODO: Envoyer une notification push ici
            return {"match": db_match, "is_new_conversation": True, "conversation_id": new_conversation.id}

    return {"match": db_match, "is_new_conversation": False, "conversation_id": None}
