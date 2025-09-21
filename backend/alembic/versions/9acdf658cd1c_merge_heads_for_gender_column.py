"""Merge heads for gender column

Revision ID: 9acdf658cd1c
Revises: 20250921_add_gender_to_users, 2affd04a960d
Create Date: 2025-09-21 14:16:46.058930

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9acdf658cd1c'
down_revision: Union[str, Sequence[str], None] = ('20250921_add_gender_to_users', '2affd04a960d')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
