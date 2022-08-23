import boto3
import os
import json
import datetime 
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from resources import Secret
def lambda_handler(event, context):
    main()

    return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin":"*",
                    "Content-Type": "application/json"
                },
                "body": "Success"
            }

class Authentication():
    def __init__(self, client_id,client_secret):
        self.client_id = client_id
        self.client_secret = client_secret
    def get_authectication(self):
        spotify = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials(client_id=self.client_id, client_secret=self.client_secret))
        return spotify
    def __repr__(self):
        return "<Test a:%s b:%s>" % (self.client_id, self.client_secret)

    def __str__(self):
        return "client_id is %s, and client_secret is %s" % (self.client_id, self.client_secret)

class data():
    def __init__(self):
        self.secret =  Secret()

    def auth(self):
        authenticate = Authentication(self.secret.client_id,self.secret.client_secret)
        return authenticate
    
    def get_auth(self):
        auth = self.auth()
        return auth.get_authectication()
    
    def get_playlists(self,country_code):
        auth = self.get_auth()
        return [i['uri'] for i in auth.featured_playlists('en',country_code,timestamp= datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ") ,limit=50)['playlists']['items']]
        
    def get_artist(self,artist_id):
        auth = self.get_auth()
    
    def playlist(self, playlist_id):
        data_array = []
        dataset = {}
        auth = self.get_auth()
        for i in playlist_id:
            dataset = {'name':auth.playlist(i)['name'], 'followers': auth.playlist(i)['followers']['total']}
            data_array.append(dataset)
        with open(r'C:\Users\VivekVelivela\Desktop\Data Viz project\Data\Data.js', 'w') as file:
            file.write('export const UserData = %s;'% json.dumps(data_array))


            


def main():
    data().playlist(data().get_playlists('IN'))

if __name__ == "__main__":
    main()
    