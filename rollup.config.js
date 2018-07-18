import babel from 'rollup-plugin-babel';
import cleanup from 'rollup-plugin-cleanup';

export default {
  input: 'lib/routes-src.js',
  output: {
    file: 'lib/routes.js',
    format: 'umd',
    name: 'NAMESPACE'
  },
  plugins: [
    babel({
      exclude: 'node_modules/**'
    }),
    cleanup()
  ]
};
