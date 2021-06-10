import aiohttp
import asyncio
import argparse
import time
import json
import logging
from collections import defaultdict

API_KEY = 'AIzaSyDsfVacYwzSLbPoA4oe7GhivUsCxafIYg8'

servers = {
    'Riley': 12160, 
    'Jaquez': 12161, 
    'Juzang': 12162, 
    'Campbell': 12163, 
    'Bernard': 12164
}

friends = {
    'Riley': ['Jaquez', 'Juzang'],
    'Jaquez': ['Riley','Bernard'],
    'Juzang': ['Riley', 'Bernard', 'Campbell'],
    'Campbell': ['Juzang', 'Bernard'],
    'Bernard': ['Jaquez', 'Juzang', 'Campbell']
}

def is_number(string):
    try:
        float(string)
        return True
    except ValueError:
        return False

# code adapted from the TA Hint Github
class Server:

    def __init__(self, name, port, ip='127.0.0.1'):
        self.name = name
        self.port = port
        self.ip = ip
        self.client_info = dict()
        self.client_msg = dict()
        self.friends = set()


    async def flood(self, message):
        """
        for each friend: open a connection
                         send the message
                         close the connection
        """
        for friend in friends[self.name]:
            try:
                reader, writer = await asyncio.open_connection(host='127.0.0.1', port=servers[friend])
                logging.info(f'{self.name} sent {message} to {friend}')
                writer.write(message.encode())
                await writer.drain()
                logging.info(f'{self.name} closed connection to {friend}')
                writer.close()
                await writer.wait_close()
            except:
                logging.info(f'{friend} was not available')


    async def parse_message(self, message):
        words = message.strip().split()
        sendback_message = None

        """
        message from another server
        """
        if words[0] == 'AT':
            if self.name not in words[2:]:
                logging.info(f'{self.name} received propagated message: {message}')

                if words[3] in self.client_info and float(words[5]) > self.client_info[words[3]][1]:
                    logging.info(f'{self.name} updated client info: {message}')
                    self.client_msg[words[3]] = message;
                else:
                    logging.info(f'{self.name} added new client info: {message}')
                    saved_message = message.split()
                    saved_message = saved_message[:6]
                    saved_message = ' '.join(saved_message)
                    self.client_msg[words[3]] = saved_message;

                self.client_info[words[3]] = (words[4], float(words[5]))
                await self.flood(message + f' {self.name}')

            else:
                logging.info(f'{self.name} already received propagated message: {message}')

            return sendback_message
        
        """
        message from client
        """
        if words[0] == 'IAMAT' and self.check_IAMAT(words):
            logging.info(f'{self.name} received "{message}" from client')
            self.client_info[words[1]] = (words[2], float(words[3]))
            diff = time.time() - float(words[3])
            sign = '+' if diff > 0 else '-'
            sendback_message = f'AT {self.name} {sign}{diff:.9f} {words[1]} {words[2]} {words[3]}'
            self.client_msg[words[1]] = sendback_message
            await self.flood(sendback_message + f' {self.name}')
        elif words[0] == 'WHATSAT' and self.check_WHATSAT(words):
            logging.info(f'{self.name} received "{message}" from client')
            loc = self.client_info[words[1]][0].split('-')
            loc = loc[0] + ',-' + loc[1]
            rad = str(int(words[2])/1000) # convert km to m
            max_results = int(words[3])
            url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?key={0}&location={1}&radius={2}'.format(API_KEY, loc, rad)            
            
            logging.info(f'{self.name} attempting to retrieve places at location {loc}')
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as resp:
                    nearby_results = await resp.json() # json type is dict
                    logging.info(f'{self.name} retrieved location {loc} from Google API')
                    
                    if len(nearby_results['results']) > max_results:
                        nearby_results['results'] = nearby_results['results'][0:max_results]

                    search_result = json.dumps(nearby_results, sort_keys=True, indent=4).rstrip('\n') #json2string, remove trailing newlines
                    sendback_message = f'{self.client_msg[words[1]]}\n{search_result}\n\n'
        else:
            sendback_message = '? ' + message

        return sendback_message


    async def handle_msg(self, reader, writer):
        while not reader.at_eof():
            data = await reader.readline() 
            message = data.decode()
            sendback_message = await self.parse_message(message)

            if sendback_message != None:
                writer.write(sendback_message.encode())
                logging.info(f'{self.name} sent {sendback_message} to client')
            await writer.drain()
        
            logging.info('Close the client socket')
            writer.close()


    def check_IAMAT(self, words):
        long_lat = words[2].replace('-','+')
        long_lat = long_lat.split('+')

        if len(words) != 4 or not is_number(long_lat[1]) or not is_number(long_lat[2]) or not is_number(words[3]):
            return False
        
        return True
    

    def check_WHATSAT(self, words):
        if int(words[2]) < 0 or 50 < int(words[2]) or int(words[3]) < 0 or int(words[3]) > 20:
            return False

        if len(words) != 4 or not is_number(words[2]) or not is_number(words[3]) or not words[1] in self.client_info:
            return False

        if not words[1] in self.client_info:
            logging.info(f'{self.name} does not have this client {words[1]}\'s information')
            return False
        
        return True


    async def run_forever(self):
        logging.info(f'server {self.name} starting up')
        server = await asyncio.start_server(self.handle_msg, self.ip, self.port)

        # Serve requests until Ctrl+D is pressed
        async with server:
            await server.serve_forever()
        
        # Close the server
        logging.info(f'server {self.name} shutting down')
        server.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('server_name', type=str, help='required server name input')
    args = parser.parse_args()

    if args.server_name not in servers:
        parser.error('Server name must be Riley, Jaquez, Juzang, Campbell, or Bernard')

    log_file = args.server_name + '.log'
    logging.basicConfig(filename=log_file, format='%(message)s', level=logging.INFO)
    server = Server(args.server_name, servers[args.server_name])
    try:
        asyncio.run(server.run_forever())
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
