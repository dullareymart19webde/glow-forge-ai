import { Client, Account, Databases, Storage } from 'appwrite';

export const appwriteConfig = {
    projectId: '6aa9f963003c56fa1a88',
    bucketId: '6aa9f9e30014bda4a6ff',
    databaseId: '6aaa09da0021ae343f57',
    tableId: '6aaa0d9100160e81c694'
};

const client = new Client();
client
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject(appwriteConfig.projectId);

export const account = new Account(client);
export const databases = new Databases(client);
export const storage = new Storage(client);
export default client;
