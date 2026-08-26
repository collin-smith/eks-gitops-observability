from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ItemCreate(BaseModel):
    name: str
    description: str | None = None


class ItemOut(ItemCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
