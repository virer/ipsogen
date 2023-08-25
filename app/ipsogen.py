#!/usr/bin/env python3
######################
# S.CAPS Jul 2022
######################
from flask import Flask, request, render_template, request, jsonify, send_file
import os, yaml, subprocess, uuid

app = Flask(__name__)
app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0

@app.route("/", methods=["GET", "POST"])
def index():
    context = {}
    return render_template("index.html", context=context)

@app.route("/ipsogen", methods=["POST"])
def api_iso_gen_and_download():
    myuuid = str(uuid.uuid1())
    app.logger.info("Generating ISO... {0}".format(myuuid))
    app.config["IPSOGEN"] = get_config()
    
    embed_file      = myuuid + "_scaps.ipxe"
    cmd_line        = app.config["IPSOGEN"]["ipxe_cmd_line"]
    source_dir      = app.config["IPSOGEN"]["ipxe_source"]
    build_dir       = app.config["IPSOGEN"]["ipxe_build"]
    output_filepath = build_dir + myuuid + "_ipxe_uefi.iso"

    # check if the post request has specified filename to be return
    return_filename = "ipsogen.iso"
    if "filename" in request.form:
        return_filename = request.form["filename"]

    # check if the post request has the file part
    if "file" not in request.files:
        jsonify( { "status": "bad", "message": "no file part !" } ), 400        

    try:
        file = request.files['file']
        file.save(source_dir + "" + embed_file)
    except Exception as e:
        app.logger.error("Error in the writing phase : {0}".format(e))
        return jsonify( { "status": "bad", "message": "Write issue!?" } ), 500       

    try:
        app.logger.debug("Build ISO using this command line {0} here {1}".format(cmd_line, build_dir) )
        # Build iso file
        p = subprocess.Popen([ 'time', '/bin/bash',  cmd_line, myuuid ], cwd=build_dir + "")
        p.wait()
    except Exception as e:
        app.logger.error("Error in the build phase : {0}".format(e))
        return jsonify( { "status": "bad", "message": "Build error !" } ), 500

    os.remove(source_dir + "" + embed_file)

    return send_file(output_filepath, attachment_filename=return_filename, as_attachment=True , mimetype="application/octet-stream")

def get_config():
    with open(r'/config/config.yaml') as file:
        return yaml.load(file, Loader=yaml.FullLoader)

if __name__ == "__main__":
    app.config["IPSOGEN"] = get_config()
    app.run(host=app.config["IPSOGEN"]["bind_address"], port=int(app.config["IPSOGEN"]["bind_port"]), debug=bool(app.config["IPSOGEN"]["DEBUG"]))