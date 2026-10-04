from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from utils.dependencies import get_current_user
from config.database import get_database_connection
from routers.auth import router as auth_router
from routers.patients import router as patients_router
from routers.services import router as services_router
from routers.appointments import router as appointments_router
from routers.health_journey import router as health_journey_router
from routers.chat import router as chat_router
from routers.messages import router as messages_router
from routers.reminders import router as reminders_router
from routers.articles import router as articles_router


app = FastAPI(
    title="Women's Health Companion API",
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth_router)
app.include_router(patients_router)
app.include_router(services_router)
app.include_router(appointments_router)
app.include_router(health_journey_router)
app.include_router(chat_router)
app.include_router(messages_router)
app.include_router(reminders_router)
app.include_router(articles_router)

@app.get("/")
def root():
    return {
        "message": "Women's Health Companion API is running"
    }


@app.get("/database-test")
def database_test(current_user=Depends(get_current_user)):
    connection = get_database_connection()

    if connection.is_connected():
        connection.close()

        return {
            "database": "connected",
            "message": "FastAPI successfully connected to the database"
        }

    return {
        "database": "not connected"
    }