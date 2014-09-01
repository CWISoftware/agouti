require 'spec_helper'

describe Agouti::Rack::PackageLimiter do

  let(:app) { double('app', call: [status, headers, body]) }
  let(:status) { 200 }
  let(:body) { [] }

  describe '#call' do

    subject { described_class.new(app).call(env) }

    context 'when header X-Agouti-Enable is set' do

      context 'when header X-Agouti-Enable is set with 1' do

        let(:headers) { { 'X-Agouti-Enable' => 1 } }
        let(:env) { { 'HTTP_X_AGOUTI_ENABLE' => 1 } }

        context 'when the request response is not an html' do
          it 'returns status code 204' do
            expect(subject). to match_array([204, {}, []])
          end
        end

        context 'when header X-Agouti-Limit is not set' do
          let(:content_type_header) { { 'Content-Type' => 'text/html' } }

          it 'returns gzipped data truncated at 14000 bytes' do
            headers.merge!(content_type_header)

            st, hd, bd = subject

            expect(st).to eq(200)
            expect(hd).to eq(headers.merge!('Content-Encoding' => 'gzip'))
            expect(bd).to be_a(Agouti::Rack::PackageLimiter::GzipTruncatedStream)
            expect(bd.byte_limit).to eq(14000)
          end
        end

        context 'when header X-Agouti-Limit is set' do
          context 'when header X-Agouti-Limit is set with a valid number of bytes' do
            let(:limit_header) { { 'X-Agouti-Limit' => 10 } }
            let(:content_type_header) { { 'Content-Type' => 'text/html' } }
            let(:limit_env) { { 'HTTP_X_AGOUTI_LIMIT' => 10 } }

            it 'returns gzipped data with given number of bytes' do
              headers.merge!(limit_header)
              headers.merge!(content_type_header)
              env.merge!(limit_env)


              st, hd, bd = subject

              expect(st).to eq(200)
              expect(hd).to eq(headers.merge!('Content-Encoding' => 'gzip'))
              expect(bd).to be_a(Agouti::Rack::PackageLimiter::GzipTruncatedStream)
              expect(bd.byte_limit).to eq(10)
            end
          end

          context 'when header X-Agouti-Limit is set with an invalid value' do
            let(:headers) { { 'X-Agouti-Limit' => 'foobar' } }
            let(:env) { { 'HTTP_X_AGOUTI_LIMIT' => 'foobar' } }

            it 'raises invalid header exception' do
              expect { subject }.to raise_exception(Agouti::Rack::PackageLimiter::InvalidHeaderException)
            end
          end
        end
      end

      context 'when header X-Agouti-Enable is set with 0' do
        let(:headers) { { 'X-Agouti-Enable' => 0 } }
        let(:env) { { 'HTTP_X_AGOUTI_ENABLE' => 0 } }

        it 'does nothing' do
          expect(subject). to match_array([200, headers, []])
        end
      end

      context 'when header X-Agouti-Enable is set with an invalid value' do
        let(:headers) { { 'X-Agouti-Enable' => 'foobar' } }
        let(:env) { { 'HTTP_X_AGOUTI_ENABLE' => 'foobar' } }

        it 'raises invalid header exception' do
          expect { subject }.to raise_exception(Agouti::Rack::PackageLimiter::InvalidHeaderException)
        end
      end
    end

    context 'when header X-Agouti-Enable is not set' do
      let(:headers) { { } }
      let(:env) { { } }

      it 'does nothing' do
        expect(subject). to match_array([200, headers, []])
      end
    end
  end
end
