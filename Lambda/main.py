import boto3
import os
import json
import datetime 
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from resources import Secret
from github import Github
import pandas as pd
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

class Authentication:
    def __init__(self, client_id,client_secret, github_access_token):
        self.client_id = client_id
        self.client_secret = client_secret
        self.github_access_token = github_access_token
    def get_authectication(self):
        spotify = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials(client_id=self.client_id, client_secret=self.client_secret))
        return spotify
    # def __repr__(self):
    #     return "<Test a:%s b:%s>" % (self.client_id, self.client_secret)

    # def __str__(self):
    #     return "client_id is %s, and client_secret is %s" % (self.client_id, self.client_secret)



class github:
    def __init__(self, access_token, content):
        self.github_auth = Github(access_token)
        self.content = content
        self.update_repo
    def update_repo(self, content_file, commit_message):
        repo = self.github_auth.get_repo("vivekVelivela/spotipyFrontend")
        contents = repo.get_contents(content_file, ref="master")
        response = repo.update_file(contents.path, commit_message, self.content, contents.sha, branch="master")
        return response
        



class data:
    def __init__(self):
        self.secret =  Secret()

    def auth(self):
        authenticate = Authentication(self.secret.client_id,self.secret.client_secret, self.secret.github_access_token)
        return authenticate
    
    def get_auth(self):
        auth = self.auth()
        return auth.get_authectication()
    
    def get_playlists(self,country_code):
        auth = self.get_auth()
        return [i['uri'] for i in auth.featured_playlists('en',country_code,timestamp= datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ") ,limit=50)['playlists']['items']]
    

    # def get_artist(self, playlist_id):
        # # playlist_array = []
        # # playlist = {}
        # auth = self.get_auth()
        # print(auth.artist('2JSYASbWU5Y0fVpts3Eq7g'))
        # artist_array = []
        # auth = self.get_auth()
        # for i in playlist_id:
        #     artist_array.append([[k['artist']['name'],k['artist']['popularity']] for k in auth.playlist(i, additional_types=('track',))['tracks']['items']])
        # flatlist=[element for sublist in artist_array for element in sublist]
        # df = pd.DataFrame(flatlist, columns = ['track', 'popularity']).drop_duplicates(subset=['track']).sort_values(by = ['popularity'], ascending=False)
        # df_new = df.head(10)
        # return df_new.to_dict(orient='records')
    
    def playlists(self, playlist_id):
        playlist_array = []
        playlist = {}
        auth = self.get_auth()
        for i in playlist_id:
            playlist = {'name':auth.playlist(i)['name'], 'followers': auth.playlist(i)['followers']['total']}
            playlist_array.append(playlist)
        return playlist
    
    def tracks(self,playlist_id):
        track_array = []
        auth = self.get_auth()
        for i in playlist_id:
            track_array.append([[k['track']['name'],k['track']['popularity']] for k in auth.playlist(i, additional_types=('track',))['tracks']['items']])
        flatlist=[element for sublist in track_array for element in sublist]
        df = pd.DataFrame(flatlist, columns = ['track', 'popularity']).drop_duplicates(subset=['track']).sort_values(by = ['popularity'], ascending=False)
        df_new = df.head(10)
        return df_new.to_dict(orient='records')
    
    
    def testing_for_data(self,playlist_id):
        auth = self.get_auth()
        for i in playlist_id:
            k = auth.artist(i)
            print(self.parse_json(k))
            break

            
        # return playlist_array
    




        # github_auth = github(self.auth().github_access_token,'export const UserData = %s;'% json.dumps(data_array))
        # commit = github_auth.update_repo("src/components/Data.js", "updating_data_files")
        # commit

# Helper function to extract and map complex and Nested JSON objects
    def parse_json(self,data):
        for key,value in data.items():
            print (str(key)+'->'+str(value))
            if isinstance(value, dict):
                self.parse_json(value)
            elif isinstance(value, list):
                for val in value:
                    if isinstance(val, str):
                        # print(val)
                        pass
                    elif isinstance(val, list):
                        pass
                    else:
                        self.parse_json(val)

            


def main():
    # data().playlist(data().get_playlists('IN'))
    data().testing_for_data(data().get_playlists('IN'))
    # data().get_artist()

if __name__ == "__main__":
    main()
    