import nextConfig from 'eslint-config-next';

const eslintConfig = [
    ...nextConfig,
    {
        rules: {
            'react-hooks/exhaustive-deps': 'off',
            'react-hooks/set-state-in-effect': 'off',
        },
    },
];

export default eslintConfig;
