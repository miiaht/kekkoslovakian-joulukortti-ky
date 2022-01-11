from google.cloud import storage
import json
import os

def return_images(request):
    try:
        """Lists all the blobs in the bucket."""

        bucket_name = os.environ.get('bucket')

        storage_client = storage.Client()

        # Note: Client.list_blobs requires at least package version 1.17.0.
        blobs = storage_client.list_blobs(bucket_name)
        list_blobs = []
        for blob in blobs:
            if "png" in blob.name:
                list_blobs.append(blob.name)
            #todo kuinka jsonittaa blobi
        json_list = json.dumps(list_blobs, default=str, indent=4, sort_keys=True)
        print(json_list)
        return json_list

    except Exception as e:
        print(e)
        return "blib blob"

    