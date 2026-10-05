import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { db } from './db';

export const usersRepo = {
    authenticate,
    getAll,
    getById,
    create,
    update,
    delete: _delete,
};

function collection() {
    return db.pb.collection(db.collection);
}

function toUser(record) {
    const { id, username, firstName, lastName } = record;
    return { id, username, firstName, lastName };
}

function escapeFilterValue(value) {
    return String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

async function authenticate({ username, password }) {
    const filter = `username = "${escapeFilterValue(username)}"`;
    const record = await collection().getFirstListItem(filter).catch(() => null);

    if (!(record && bcrypt.compareSync(password, record.hash))) {
        throw 'Username or password is incorrect';
    }

    const token = jwt.sign({ sub: record.id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    return {
        ...toUser(record),
        token,
    };
}

async function getAll() {
    const records = await collection().getFullList({ sort: 'username' });
    return records.map(toUser);
}

async function getById(id) {
    const record = await collection().getOne(id).catch(() => null);
    if (!record) {
        throw 'User not found';
    }
    return toUser(record);
}

async function create(params) {
    const filter = `username = "${escapeFilterValue(params.username)}"`;
    if (await collection().getFirstListItem(filter).catch(() => null)) {
        throw `Username "${params.username}" is already taken`;
    }

    const hash = params.password ? bcrypt.hashSync(params.password, 10) : '';
    await collection().create({
        username: params.username,
        firstName: params.firstName,
        lastName: params.lastName,
        hash,
    });
}

async function update(id, params) {
    const record = await collection().getOne(id).catch(() => null);
    if (!record) {
        throw 'User not found';
    }

    if (params.username && params.username !== record.username) {
        const filter = `username = "${escapeFilterValue(params.username)}"`;
        if (await collection().getFirstListItem(filter).catch(() => null)) {
            throw `Username "${params.username}" is already taken`;
        }
    }

    const body = {
        username: params.username ?? record.username,
        firstName: params.firstName ?? record.firstName,
        lastName: params.lastName ?? record.lastName,
        hash: record.hash,
    };

    if (params.password) {
        body.hash = bcrypt.hashSync(params.password, 10);
    }

    await collection().update(id, body);
}

async function _delete(id) {
    const record = await collection().getOne(id).catch(() => null);
    if (!record) {
        throw 'User not found';
    }
    await collection().delete(id);
}
