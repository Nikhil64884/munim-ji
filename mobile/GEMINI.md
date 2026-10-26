# Munim Ji Project Rules

- **Tech Stack**: Backend: FastAPI + SQLAlchemy + SQLite. Frontend: Flutter app.
- **Money Handling**: Sab paise paise (integer) mein store honge, kabhi float nahi (`balance_paise`, etc.).
- **Consistency**: Existing code ka naam, structure aur style kabhi mat badlo.
- **Targeted Changes**: Sirf wahi files badlo jo task ke liye zaroori hain.
- **Database Safety**: DB column jodna ho to migration likho, purana data na toote.
- **Dependencies**: Naye packages tabhi jodo jab bahut zaroori ho, pehle user se poochiye.
- **Security**: Har naye API endpoint par auth (JWT) lagao.
- **Change Summary & Testing**: Kaam ke baad hamesha batao: kaun si files badli aur kaise test karein.
