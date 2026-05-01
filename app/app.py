from flask import Flask, render_template, request, redirect, url_for
from pymongo import MongoClient
import os

app = Flask(__name__)

def get_db():
    mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    client = MongoClient(mongo_uri, serverSelectionTimeoutMS=3000)
    return client["inventory_db"]

STARTER_PRODUCTS = [
    {"name": "Sweatshirt",    "stock": 50},
    {"name": "T-shirt",    "stock": 30},
    {"name": "Baseball Hat",    "stock": 20},
    {"name": "Polo shirt",    "stock": 15},
    {"name": "Athletic Shorts", "stock": 40},
]

def seed_db(db):
    if db["products"].count_documents({}) == 0:
        db["products"].insert_many(STARTER_PRODUCTS)

@app.route("/")
def index():
    db = get_db()
    seed_db(db)
    products = list(db["products"].find())
    return render_template("index.html", products=products)

@app.route("/order", methods=["GET", "POST"])
def order():
    db = get_db()
    seed_db(db)
    message = None
    if request.method == "POST":
        name = request.form.get("product")
        try:
            qty = int(request.form.get("quantity", 1))
        except ValueError:
            qty = 1
        product = db["products"].find_one({"name": name})
        if not product:
            message = "Product not found."
        elif product["stock"] < qty:
            message = f"Insufficient stock. Only {product['stock']} units available."
        else:
            db["products"].update_one({"name": name}, {"$inc": {"stock": -qty}})
            message = f"Order placed! {qty}x {name} shipped successfully."
    products = list(db["products"].find())
    return render_template("order.html", products=products, message=message)

@app.route("/restock", methods=["GET", "POST"])
def restock():
    db = get_db()
    seed_db(db)
    message = None
    if request.method == "POST":
        name = request.form.get("product")
        try:
            qty = int(request.form.get("quantity", 1))
        except ValueError:
            qty = 1
        product = db["products"].find_one({"name": name})
        if not product:
            message = "Product not found."
        else:
            db["products"].update_one({"name": name}, {"$inc": {"stock": qty}})
            message = f"Restock complete! Added {qty}x {name} to inventory."
    products = list(db["products"].find())
    return render_template("restock.html", products=products, message=message)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)