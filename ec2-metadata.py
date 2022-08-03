import requests
import json

metadata_url = 'http://169.254.169.254/latest/'


def expand(url, arg):
    output = {}
    for i in arg:
        new_url = url + i
        x = requests.get(new_url)
        text = x.text
        if i[-1] == "/":
            list_of_values = x.text.splitlines()
            output[i[:-1]] = expand(new_url, list_of_values)
        elif is_json(text):
            output[i] = json.loads(text)
        else:
            output[i] = text
    return output


def get_metadata():
    folder = ["meta-data/"]
    result = expand(metadata_url, folder)
    return result


def get_metadata_json():
    metadata = get_metadata()
    metadata_json = json.dumps(metadata, indent=4, sort_keys=True)
    return metadata_json


def is_json(myjson):
    try:
        json.loads(myjson)
    except ValueError:
        return False
    return True


if __name__ == '__main__':
    print(get_metadata_json())