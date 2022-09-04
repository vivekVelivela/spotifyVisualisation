from array import array
import doctest
import traceback
import boto3
import os
import json
import datetime 
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from resources import Secret
from github import Github
import pandas as pd
import random
def lambda_handler(event, context):
    Data = data()
    Data.commit_data()
    # countries = ['IN','GB']
    # a = random.randint(0,len(countries)-1)
    # playlist_ids = Data.get_playlists(countries[a])
    # artist_ids = Data.get_artist_id(playlist_ids)
    # print(artist_ids)
    # print(data().get_playlists('GB'))

    # return {
    #             "statusCode": 200,
    #             "headers": {
    #                 "Access-Control-Allow-Origin":"*",
    #                 "Content-Type": "application/json"
    #             },
    #             "body": "Success"
    #         }

class Authentication:
    def __init__(self, client_id,client_secret, github_access_token):
        self.client_id = client_id
        self.client_secret = client_secret
        self.github_access_token = github_access_token
    def get_authectication(self):
        spotify = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials(client_id=self.client_id,
         client_secret=self.client_secret,proxies=None, requests_session=True, 
         requests_timeout=None, cache_handler=None))
        return spotify



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
        # k = auth.featured_playlists('en',country_code,timestamp= datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"))
        # for i in auth.featured_playlists('en',country_code,timestamp= datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ") ,limit=50)['playlists']['items']:
        return [i['uri'] for i in auth.featured_playlists('en',country_code,timestamp= datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ") ,limit=50)['playlists']['items']]
    
    # def get_playlist_items(self, playlist_id):
    #     auth = self.get_auth()
    #     for i in playlist_id:
    #         print(auth.playlist_items(i))
    #         break
    def get_artist_id(self, playlist_id):
        try:
            artist_id_df = pd.DataFrame(columns=['name','uri'])
            artist_id_array = []
            auth = self.get_auth()
            for i in playlist_id:
                artist_id_array.append([k for k in auth.playlist(i, additional_types=('track',))['tracks']['items']])
            for i in artist_id_array:
                for k in i:
                    if k == None:
                        print(i)
                    for v in range(len(k["track"]['album']['artists'])):
                        artist_id_df =  artist_id_df.append({'name':k["track"]['album']['artists'][v]['name'],'uri':k["track"]['album']['artists'][v]['uri']},ignore_index=True )
            artist_id_df = artist_id_df.drop_duplicates(subset=['uri'])
            return artist_id_df
        except Exception as e:
            print(e)
    
    def get_artist(self,df):
        artist_df = pd.DataFrame(columns=['name','popularity'])
        auth = self.get_auth()
        for index,row in df.iterrows():
            i = auth.artist(row['uri'])
            artist_df =  artist_df.append({"name":i['name'],'popularity':i['popularity']},ignore_index=True )
        artist_df = artist_df.sort_values(by = ['popularity'], ascending=False)
        artist_df_new = artist_df.head(10)
        return artist_df_new.to_dict(orient='records')
                   
    
    def playlist(self, playlist_id):
        playlist_array = []
        auth = self.get_auth()
        for i in playlist_id:
            playlist = {'name':auth.playlist(i)['name'], 'followers': auth.playlist(i)['followers']['total']}
            playlist_array.append(playlist)
        return playlist_array
    
    def tracks(self,playlist_id):
        track_array = []
        auth = self.get_auth()
        for i in playlist_id:
            track_array.append([[k['track']['name'],k['track']['popularity'], k['track']['uri']] for k in auth.playlist(i, additional_types=('track',))['tracks']['items'] if k['track'] is not None])
        flatlist=[element for sublist in track_array for element in sublist]
        df = pd.DataFrame(flatlist, columns = ['track', 'popularity', 'uri']).drop_duplicates(subset=['track']).sort_values(by = ['popularity'], ascending=False)
        df_new = df.head(10)
        return df_new.to_dict(orient='records')
    
    def get_track_details(self,dict):
        auth = self.get_auth()
        track_details_array = []
        for i in dict:
            k = auth.audio_features(i['uri'])
            for l in k:
                 track_details_array.append({"track_name":i['track'],"danceability":l['danceability'],"energy":l['energy']})
        return track_details_array
            

    
    
    def testing_for_data(self,playlist_id):
        auth = self.get_auth()
        for i in playlist_id:
            k = auth.playlist(i, additional_types=('track',))
            print([i for i in k['tracks']['items']])
            break
    
    def commit_data(self):
        countries = ['IN','GB', 'AU']
        a = random.randint(0,len(countries)-1)
        playlist_ids = self.get_playlists(countries[a])
        artist_ids = self.get_artist_id(playlist_ids)
        track_ids = self.tracks(playlist_ids)
        github_auth = github(self.auth().github_access_token,'export const playlist_followers = %s; \n export const track_popularity = %s; \n export const artist_popularity = %s; \n export const track_details = %s; \n export const country = %s;'% (json.dumps(self.playlist(playlist_ids)),json.dumps(self.tracks(playlist_ids)),json.dumps(self.get_artist(artist_ids)),json.dumps(self.get_track_details(track_ids)),str(countries[a])))
        commit = github_auth.update_repo("src/components/Data.js", "updating_data_files")
        commit
    
    # def test(self):
    #     playlist_ids = self.get_playlists('IN')
    #     artist_ids = self.get_artist_id(playlist_ids)
    #     print('export const playlist_followers = %s; \n export const track_popularity = %s; \n export const artist_popularity = %s;'% (json.dumps(self.playlist(playlist_ids)),json.dumps(self.tracks(playlist_ids)),json.dumps(self.get_artist(artist_ids))))

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
    # data().testing_for_data(data().get_playlists('IN'))
    # Data = data()
    # df = Data.get_playlists('IN')
    # df1 = Data.tracks(df)
    # df2 = Data.get_track_details(df1)
    # Data.get_track_details()
    # df1  = Data.tracks(df)
    # df2 = Data.top_id(df1,'popularity','track')
    # data().tracks(data().get_playlists('IN'))
    Data = data()
    Data.commit_data()

if __name__ == "__main__":
    main()
    