import time
import json
import requests
from pprint import pprint

SPOTIFY_GET_CURRENT_TRACK_URL = 'https://api.spotify.com/v1/me/player/currently-playing'
SPOTIFY_ACCESS_TOKEN = '''
BQBwWtGlosMNzEySEPDAlmd1kwOJ0dAuOU-bkmb5_RZRg-EO6s2C0XZ2umppT9TggbUqDA4CkCLOgcCBfb2rziISmIpZEtpcBk6DHOxpeBPw0UWE_r0Yyc-kx3pyCKMDuQLs4VG8N9JI4O_8x4lZCG6IPIiROs9x0bDwTeoiRRwrVh0-4BMOWZM9FxSJQvblDSdh07WX
'''


def get_current_track(access_token):
    response = requests.get(
        SPOTIFY_GET_CURRENT_TRACK_URL,
        headers={
            'Authorization': 'Bearer ' + access_token
        }
    )
    resp_json = response.json()

    timelen = resp_json['item']['duration_ms'] / 1000
    timepos = resp_json['progress_ms']/1000
    track_id = resp_json['item']['id']
    track_name = resp_json['item']['name']
    track_artist = resp_json['item']['artists']
    track_artist_name = ', '.join(
        [artist['name'] for artist in track_artist]
    )
    link = resp_json['item']['external_urls']['spotify']

    current_track_info = {
        'id': track_id,
        'name': track_name,
        'artist': track_artist,
        'link': link,
        'timepos': timepos,
        'timelen': timelen
    }
    return current_track_info


def main():
    while True:
        current_track_info = get_current_track(SPOTIFY_ACCESS_TOKEN)
        with open('current_track.json', 'w') as f:
            f.write(json.dumps(current_track_info, indent=4, sort_keys=True))

        time.sleep(1)

if __name__ == '__main__':
    main()