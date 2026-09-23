from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    gemini_api_key: str = ""
    model_onnx_path: str = "model/artifacts/model.onnx"
    tokenizer_path: str = "model/artifacts/tokenizer"
    thresholds_path: str = "model/artifacts/tuned_thresholds.json"
    app_env: str = "development"
    
    # JWT Auth
    jwt_secret: str = "super_secret_key_change_in_prod"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7 # 7 days
    
    # Firebase
    firebase_credentials_path: str = "firebase-credentials.json"
    
    # SMTP Email
    smtp_server: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_email: str = "noreply@furrmind.com"


settings = Settings()
