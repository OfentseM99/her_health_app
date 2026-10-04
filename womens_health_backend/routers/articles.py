"""
routers/articles.py

Health articles. Any logged-in user can read them; only staff
(role 2/3/4) can write, edit, or delete them from the admin portal.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_database_connection
from utils.dependencies import get_current_user

router = APIRouter(prefix="/articles", tags=["Articles"])


class ArticleRequest(BaseModel):
    title: str
    body: str
    category: Optional[str] = None


class ArticleResponse(BaseModel):
    id: int
    title: str
    category: Optional[str] = None
    body: str
    created_at: str
    updated_at: str


_COLUMNS = "id, title, category, body, created_at, updated_at"


def _require_staff(current_user: dict):
    if current_user["role_id"] not in (2, 3, 4):
        raise HTTPException(status_code=403, detail="Only staff can manage articles.")


def _validate(request: ArticleRequest):
    if not request.title.strip():
        raise HTTPException(status_code=400, detail="Title can't be empty.")
    if not request.body.strip():
        raise HTTPException(status_code=400, detail="Article text can't be empty.")


def _row(r) -> dict:
    return {
        "id": r["id"],
        "title": r["title"],
        "category": r["category"],
        "body": r["body"],
        "created_at": str(r["created_at"]),
        "updated_at": str(r["updated_at"]),
    }


@router.get("", response_model=list[ArticleResponse])
def list_articles(current_user: dict = Depends(get_current_user)):
    """All articles, newest first. Any logged-in user."""
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(f"SELECT {_COLUMNS} FROM articles ORDER BY created_at DESC")
        return [_row(r) for r in cursor.fetchall()]
    finally:
        connection.close()


@router.get("/{article_id}", response_model=ArticleResponse)
def get_article(article_id: int, current_user: dict = Depends(get_current_user)):
    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(f"SELECT {_COLUMNS} FROM articles WHERE id = %s", (article_id,))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Article not found.")
        return _row(row)
    finally:
        connection.close()


@router.post("", response_model=ArticleResponse)
def create_article(
    request: ArticleRequest,
    current_user: dict = Depends(get_current_user),
):
    _require_staff(current_user)
    _validate(request)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            f"""
            INSERT INTO articles (title, category, body, author_user_id)
            VALUES (%s, %s, %s, %s)
            RETURNING {_COLUMNS}
            """,
            (
                request.title.strip(),
                (request.category or "").strip() or None,
                request.body.strip(),
                current_user["user_id"],
            ),
        )
        row = cursor.fetchone()
        connection.commit()
        return _row(row)
    finally:
        connection.close()


@router.put("/{article_id}", response_model=ArticleResponse)
def update_article(
    article_id: int,
    request: ArticleRequest,
    current_user: dict = Depends(get_current_user),
):
    _require_staff(current_user)
    _validate(request)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            f"""
            UPDATE articles
            SET title = %s, category = %s, body = %s,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING {_COLUMNS}
            """,
            (
                request.title.strip(),
                (request.category or "").strip() or None,
                request.body.strip(),
                article_id,
            ),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Article not found.")
        connection.commit()
        return _row(row)
    finally:
        connection.close()


@router.delete("/{article_id}")
def delete_article(article_id: int, current_user: dict = Depends(get_current_user)):
    _require_staff(current_user)

    connection = get_database_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "DELETE FROM articles WHERE id = %s RETURNING id", (article_id,)
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Article not found.")
        connection.commit()
        return {"message": "Article deleted."}
    finally:
        connection.close()
