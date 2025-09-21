"""
Add gender column to users table
Revision ID: 20250921_add_gender_to_users
Revises: 
Create Date: 2025-09-21
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20250921_add_gender_to_users'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('gender', sa.String(), nullable=True))

def downgrade():
    op.drop_column('users', 'gender')
