import path from 'path';
import * as esbuild from 'esbuild';

const context = await esbuild.context({
  entryPoints: ['application.js'],
  bundle: true,
  format: 'esm',
  outdir: path.join(process.cwd(), 'app/assets/builds'),
  absWorkingDir: path.join(process.cwd(), 'app/javascript'),
  publicPath: '/assets',
  sourcemap: true,
  // Rails' Dockerfile sets only RAILS_ENV; NODE_ENV=production makes Yarn 1 skip esbuild itself
  minify: [process.env.NODE_ENV, process.env.RAILS_ENV].includes('production'),
  alias: { '@': path.resolve(process.cwd(), 'app/javascript') }
});

if (process.argv.includes('--watch')) {
  await context.watch();
  console.log('watching...');
} else {
  await context.rebuild();
  await context.dispose();
}
