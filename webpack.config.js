const webpack = require('webpack');
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const config = {
  entry: './src/index.tsx',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js'
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        use: 'babel-loader',
        exclude: /node_modules/
      },
      {
        test: /\.(ts|tsx)?$/,
        loader: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\.less$/,
        use: [
          'style-loader',
          'css-loader',
          'less-loader'
        ]
      },
      {
        test: /\.glsl$/i,
        use: 'raw-loader',
      },
      {
        test: /\.(c|cpp)$/,
        use: {
          loader: 'cpp-wasm-loader'
        }
      }
    ]
  },
  resolve: {
    extensions: [
      '.js',
      '.jsx',
      '.tsx',
      '.ts',
      '.cpp',
      '.c',
      '.glsl'
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: require('html-webpack-template'),
      inject: false,
      appMountId: 'app',
    })
  ],
  optimization: {
    runtimeChunk: 'single',
    splitChunks: {
      cacheGroups: {
        vendor: {
          test: /[\\\/]node_modules[\\\/]/,
          name: 'vendors',
          chunks: 'all'
        }
      }
    }
  }
};

module.exports = config;