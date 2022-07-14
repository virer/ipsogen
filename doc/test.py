#!/usr/bin/env python3
######################
# S.CAPS Jul 2022
######################
import requests, hashlib, hmac

def postit_multipart(url, data = {}, timeout=60, verify=False):
    global shared_key
    try:
        x = requests.post(url, files=dict(data), timeout=timeout, verify=verify)
        status_code = x.status_code
        reason = x.reason
    except Exception as e:
        x = False
        status_code = 500
        reason = e

    if x and status_code == 200 or status_code == 201:
        return True, x
    else:
        print("An error occurred: {0}".format(reason))
        return False, reason

# shared_key = "0123456789"
# def postit(url, data, timeout=60, verify=False):
#     global shared_key
#     secret = bytes(str(shared_key), "UTF-8")
#     msg    = bytes(str(data), "UTF-8")
#     signature_computed = hmac.new(key=secret, msg=msg, digestmod=hashlib.sha256).hexdigest()
#     headers = {'Content-type': 'application/json', 'Connection': 'close', 'User-agent': 'IPSOGEN-Client/0.1', 'X-Signature': "sha256={0}".format(signature_computed) }
#     try:
#         x = requests.post(url, data=data, headers=headers, timeout=timeout, verify=verify)
#         status_code = x.status_code
#         reason = x.reason
#     except Exception as e:
#         x = False
#         status_code = 500
#         reason = e

#     if x and status_code == 200 or status_code == 201:
#         return True
#     else:
#         print("An error occurred: {0}".format(reason))
#         return False

if __name__ == "__main__":
    url="http://127.0.0.1:8000/ipsogen"
    f = open("test.py","r")
    filedata = f.read()
    f.close()
    data = { "filename": "mypytest.iso", "file": filedata }
    status = postit_multipart(url, data)
    if status[0] == True:
        print(status[1])