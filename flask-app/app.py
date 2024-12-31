from flask import Flask, render_template
import os
import markdown

app = Flask(__name__)


@app.route('/')
def index():
    return render_template('index.html')


@app.route("/readme")
def readme():
    # Read the README.md file
    with open("README.md", "r") as file:
        content = file.read()
    
    # Convert Markdown to HTML
    html_content = markdown.markdown(content)

    # Replace relative image paths with static paths
    html_content = html_content.replace('src="images/', 'src="/static/readme-images/images/')
    
    # Render the HTML in a template
    return render_template("readme.html", content=html_content)


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=False, host='0.0.0.0', port=port)