"""Merge all heads

Revision ID: 72c3e5e04cb6
Revises: 20250921_add_date_of_birth_to_users, 9acdf658cd1c
Create Date: 2025-09-21 15:10:05.218586

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '72c3e5e04cb6'
down_revision: Union[str, Sequence[str], None] = ('20250921_add_date_of_birth_to_users', '9acdf658cd1c')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
