import PocketBase from 'pocketbase';

export const db = {
    initialized: false,
    pb: null,
    collection: 'app_users',
    initialize,
};

const COLLECTION_SCHEMA = {
    name: 'app_users',
    type: 'base',
    fields: [
        { name: 'username', type: 'text', required: true, unique: true, min: 1, max: 255 },
        { name: 'hash', type: 'text', required: true, hidden: true, min: 1, max: 255 },
        { name: 'firstName', type: 'text', required: true, min: 1, max: 255 },
        { name: 'lastName', type: 'text', required: true, min: 1, max: 255 },
    ],
};

async function initialize() {
    const url = process.env.POCKETBASE_URL;
    const email = process.env.POCKETBASE_ADMIN_EMAIL;
    const password = process.env.POCKETBASE_ADMIN_PASSWORD;

    if (!url || !email || !password) {
        throw 'POCKETBASE_URL, POCKETBASE_ADMIN_EMAIL and POCKETBASE_ADMIN_PASSWORD are required';
    }

    const pb = new PocketBase(url);
    await pb.collection('_superusers').authWithPassword(email, password);

    const existing = await pb.collections.getOne(db.collection).catch(() => null);
    if (!existing) {
        await pb.collections.create(COLLECTION_SCHEMA);
    }

    db.pb = pb;
    db.initialized = true;
}
