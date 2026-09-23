from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    gemini_api_key: str = ""
    model_onnx_path: str = "model/artifacts/model.onnx"
    tokenizer_path: str = "model/artifacts/tokenizer"
    thresholds_path: str = "model/artifacts/tuned_thresholds.json"
    app_env: str = "development"


settings = Settings()
