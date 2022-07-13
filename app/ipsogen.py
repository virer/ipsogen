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

    # check if the post request has the file part
    if "file" not in request.files:
        jsonify( { "status": "bad", "message": "no file part !" } ), 400        
    data = request.files["file"]

    # check if the post request has specified filename to be return
    return_filename = "ipsogen.iso"
    if "filename" in request.form:
        return_filename = request.form["filename"]

    try:
        app.logger.info("Generating ISO...")
        embed_file        = "scaps.ipxe"
        cmd_line          = app.config["IPSOGEN"]["ipxe_cmd_line"]
        build_directory   = app.config["IPSOGEN"]["ipxe_source"]

        # Rendering fo the embed file
        # useless ? data = data.getvalue().decode("utf-8")
        app.logger.debug("ipxe generation: {}".format(data))
        # Copy entire build tree since target filename is not modifiable
        #    p = subprocess.Popen([ "/bin/cp", "-ar", source_directory, build_directory  ], cwd=source_directory)
        #    p.wait() 

        app.logger.debug("Embed script file %sipxe/src/%s " % (build_directory, embed_file))

        # Write embed script of the ipxe tool
        with open(build_directory + "ipxe/src/" + embed_file, "w") as f:
            f.write(data)
        f.closed

        app.logger.info("Build ISO using this command line %s here %s" % (cmd_line, build_directory) )
        # Build iso file
        p = subprocess.Popen([ '/bin/bash', cmd_line ], cwd=build_directory + "")
        p.wait()

        # Read generated iso
        iso_file_path = build_directory + "ipxe_uefi.iso"
        with open(iso_file_path, "rb") as f:
            data = f.read()

        # Clean build directory
        ## XXX shutil.rmtree(build_directory)

        return send_file(filename=iso_file_path, attachment_filename=return_filename, as_attachment=True , mimetype="application/octet-stream")

    except Exception as e:
        app.logger.error("Error in the build phase : %s" % e)
        return jsonify( { "status": "bad", "message": "Build error !" } ), 500

def get_config():
    with open(r'/config/config.yaml') as file:
        return yaml.load(file, Loader=yaml.FullLoader)

if __name__ == "__main__":
    app.config["IPSOGEN"] = get_config()
    app.run(host=app.config["IPSOGEN"]["bind_address"], port=int(app.config["IPSOGEN"]["bind_port"]), debug=bool(app.config["IPSOGEN"]["DEBUG"]))