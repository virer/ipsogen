from multiprocessing import context
from flask import Flask, render_template, request, jsonify, send_file
import os, yaml, datetime, subprocess

app = Flask(__name__)
app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0

@app.route("/", methods=["GET", "POST"])
def index():
    context = {}
    return render_template("static/index.html", context=context)

@app.route("/ipsogen", methods=["POST"])
def api_iso_gen_and_download():
    app.config["IPSOGEN"] = get_config()

    # check if the post request has the file part
    if "file" not in request.files:
        jsonify( { "status": "bad", "message": "no file part !" } ), 400        
    data = str(request.files["file"])

    # check if the post request has specified filename to be return
    return_filename = "ipsogen.iso"
    if "filename" in request.form:
        return_filename = request.form["filename"]

    app.logger.info("Generating ISO...")
    embed_file      = "scaps.ipxe"
    cmd_line        = app.config["IPSOGEN"]["ipxe_cmd_line"]
    source_dir      = app.config["IPSOGEN"]["ipxe_source"]
    build_dir       = app.config["IPSOGEN"]["ipxe_build"]
    output_filepath = build_dir + "ipxe_uefi.iso"

    try:
        app.logger.debug("Embed script file {0}{1}".format(source_dir, embed_file))
        # Write embed script of the ipxe tool
        with open(source_dir + "" + embed_file, "w") as f:
            f.write(data)
        f.closed
    except Exception as e:
        app.logger.error("Error in the writing phase : %s" % e)
        return jsonify( { "status": "bad", "message": "Build error (write issue!?)" } ), 500    

    try:
        app.logger.debug("Build ISO using this command line %s here %s" % (cmd_line, build_dir) )
        # Build iso file
        p = subprocess.Popen([ '/bin/bash', cmd_line ], cwd=build_dir + "")
        p.wait()
    except Exception as e:
        app.logger.error("Error in the build phase : %s" % e)
        return jsonify( { "status": "bad", "message": "Build error !" } ), 500
        
    # app.logger.debug("Read generated ISO")
    # Read generated iso
    # with open(output_filepath, "rb") as f:
    #   data = f.read()

    return send_file(output_filepath, attachment_filename=return_filename, as_attachment=True , mimetype="application/octet-stream")

# @app.after_request
# def after_request_func(response):
#     app.config["IPSOGEN"] = get_config()
#     output_filepath = app.config["IPSOGEN"]["ipxe_build"] + "ipxe_uefi.iso"
#     # Cleanup build 
#     os.remove(output_filepath)

#     return response

def get_config():
    with open(r'/config/config.yaml') as file:
        return yaml.load(file, Loader=yaml.FullLoader)

if __name__ == "__main__":
    app.config["IPSOGEN"] = get_config()
    app.run(host=app.config["IPSOGEN"]["bind_address"], port=int(app.config["IPSOGEN"]["bind_port"]), debug=bool(app.config["IPSOGEN"]["DEBUG"]))