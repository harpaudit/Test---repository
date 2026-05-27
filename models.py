from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()


class User(UserMixin, db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(20), default="user")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password, method="pbkdf2:sha256")

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @property
    def is_admin(self):
        return self.role == "admin"


class Dealer(db.Model):
    __tablename__ = "installers"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    # legacy columns kept for DB compat — no longer used in forms
    pic = db.Column(db.String(100), nullable=False, default="")
    phone = db.Column(db.String(30), nullable=False, default="")
    send_method = db.Column(db.String(50), nullable=False, default="Platform")
    description = db.Column(db.Text, nullable=True)
    # portal access
    website = db.Column(db.String(500), nullable=True)
    portal_username = db.Column(db.String(200), nullable=True)
    portal_password = db.Column(db.String(200), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    deals = db.relationship("Deal", backref="dealer", lazy=True)
    contacts = db.relationship(
        "DealerContact", backref="dealer", lazy=True,
        cascade="all, delete-orphan", order_by="DealerContact.id"
    )


class DealerContact(db.Model):
    __tablename__ = "dealer_contacts"
    id = db.Column(db.Integer, primary_key=True)
    dealer_id = db.Column(db.Integer, db.ForeignKey("installers.id"), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    phone = db.Column(db.String(50), nullable=True)
    email = db.Column(db.String(200), nullable=True)


class CollectionCall(db.Model):
    __tablename__ = "collection_calls"
    id = db.Column(db.Integer, primary_key=True)
    dealer_id = db.Column(db.Integer, db.ForeignKey("installers.id"), nullable=False)
    body = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)

    author = db.relationship("User", foreign_keys=[created_by])


class Status(db.Model):
    __tablename__ = "statuses"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    order = db.Column(db.Integer, nullable=False, default=99)
    color = db.Column(db.String(20), default="gray")
    is_default = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    deals = db.relationship(
        "Deal", backref="current_status", lazy=True,
        foreign_keys="Deal.current_status_id"
    )
    history_entries = db.relationship("DealStatusHistory", backref="status", lazy=True)


class Deal(db.Model):
    __tablename__ = "deals"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    installer_id = db.Column(db.Integer, db.ForeignKey("installers.id"), nullable=False)

    use_redline = db.Column(db.Boolean, default=True)

    # Redline fields
    system_size = db.Column(db.Float, nullable=True)
    company_redline = db.Column(db.Float, nullable=True)
    adders = db.Column(db.Float, nullable=True, default=0.0)
    contract_amount = db.Column(db.Float, nullable=True)

    # Calculated & stored
    total_commission = db.Column(db.Float, nullable=True)
    total_ppw = db.Column(db.Float, nullable=True)
    net_ppw = db.Column(db.Float, nullable=True)

    # Non-redline field
    amount_owed = db.Column(db.Float, nullable=True)

    # Payment tracking
    amount_paid = db.Column(db.Float, default=0.0, nullable=False)

    current_status_id = db.Column(db.Integer, db.ForeignKey("statuses.id"), nullable=True)
    notes = db.Column(db.Text, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)

    creator = db.relationship("User", foreign_keys=[created_by])
    status_history = db.relationship(
        "DealStatusHistory", backref="deal", lazy=True,
        order_by="DealStatusHistory.changed_at"
    )
    payments = db.relationship(
        "Payment", backref="deal", lazy=True,
        order_by="Payment.paid_at"
    )

    @property
    def original_value(self):
        if self.use_redline:
            return self.total_commission or 0.0
        return self.amount_owed or 0.0

    @property
    def remaining_balance(self):
        return round(max(self.original_value - (self.amount_paid or 0.0), 0.0), 2)

    @property
    def pipeline_value(self):
        return self.remaining_balance

    @property
    def payment_pct(self):
        orig = self.original_value
        if orig <= 0:
            return 100
        return min(round((self.amount_paid or 0.0) / orig * 100, 1), 100)


class DealStatusHistory(db.Model):
    __tablename__ = "deal_status_history"
    id = db.Column(db.Integer, primary_key=True)
    deal_id = db.Column(db.Integer, db.ForeignKey("deals.id"), nullable=False)
    status_id = db.Column(db.Integer, db.ForeignKey("statuses.id"), nullable=False)
    changed_at = db.Column(db.DateTime, default=datetime.utcnow)
    changed_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    note = db.Column(db.String(500), nullable=True)

    changer = db.relationship("User", foreign_keys=[changed_by])


class Payment(db.Model):
    __tablename__ = "payments"
    id = db.Column(db.Integer, primary_key=True)
    deal_id = db.Column(db.Integer, db.ForeignKey("deals.id"), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    paid_at = db.Column(db.DateTime, default=datetime.utcnow)
    recorded_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    note = db.Column(db.String(500), nullable=True)

    recorder = db.relationship("User", foreign_keys=[recorded_by])
