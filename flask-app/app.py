from flask import Flask, render_template
import os

app = Flask(__name__)


@app.route('/')
def index():
    return render_template('index.html')


if __name__ == "__main__":
    PORT = int(os.environ.get('PORT', 5000))
    IP = os.environ.get('IP', "0.0.0.0")
    app.run(debug=False, IP=IP, PORT=PORT)