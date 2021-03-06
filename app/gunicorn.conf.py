from fileinput import filename
import uuid, os

def pre_request(worker, req):
    # Adding uuid to headers
    req.headers.append( ('HTTP_UUID', "{}".format(uuid.uuid4()) ) )

def post_request(worker, req, environ, resp):
    try:
        # Cleanup generated files after request is closed (as it is not possible via after_request in flask)
        myuuid = dict(req.headers)["HTTP_UUID"]
        filename = "/ipxe.git/" + myuuid + "_ipxe_uefi.iso"
        if os.path.exists(filename):
            os.remove(filename)
    except Exception as e:
        print(e)
        pass