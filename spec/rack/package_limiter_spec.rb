require 'spec_helper'

describe Agouti::Rack::PackageLimiter do

  let(:app) { ->(env) { [200, headers, []] } }

  describe '#call' do

    subject { described_class.new(app).call(env) }

    context 'when header X-Agouti-Enable is set' do

      context 'when header X-Agouti-Enable is set with 1' do
        let(:headers) { { 'X-Agouti-Enable' => '1' } }
        let(:env) { { 'HTTP_X_AGOUTI_ENABLE' => '1' } }

        context 'when the request response is not an html' do
          it 'returns status code 204' do
            expect(subject). to match_array([204, {}, []])
          end
        end

        context 'when header X-Agouti-Limit is not set' do
          it 'returns gzipped data truncated at 14000 bytes' do
            headers.merge!('Content-Type' => 'text/html')

            response_status, response_headers, response_body = subject

            expect(response_status).to eq(200)
            expect(response_headers).to include(headers.merge!('Content-Encoding' => 'gzip'))
            expect(response_body).to be_a(Agouti::Rack::PackageLimiter::GzipTruncatedStream)
            expect(response_body.instance_variable_get(:@byte_limit)).to eq(14000)
          end
        end

        context 'when header X-Agouti-Limit is set' do

          context 'when header X-Agouti-Limit is set with a valid number of bytes' do
            it 'returns gzipped data with given number of bytes' do
              headers.merge!('X-Agouti-Limit' => '10', 'Content-Type' => 'text/html')
              env.merge!('HTTP_X_AGOUTI_LIMIT' => '10')

              response_status, response_headers, response_body = subject

              expect(response_status).to eq(200)
              expect(response_headers).to include(headers.merge!('Content-Encoding' => 'gzip'))
              expect(response_body).to be_a(Agouti::Rack::PackageLimiter::GzipTruncatedStream)
              expect(response_body.instance_variable_get(:@byte_limit)).to eq(10)
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
        let(:headers) { { 'X-Agouti-Enable' => '0' } }
        let(:env) { { 'HTTP_X_AGOUTI_ENABLE' => '0' } }

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
