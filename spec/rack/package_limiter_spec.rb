require 'spec_helper'

describe Agouti::Rack::PackageLimiter do

  subject { Agouti::Rack::PackageLimiter.new(app) }

  let(:app) { double }

  before do
    allow(app).to receive(call).with(app).and_return([status, headers, body])
  end

  describe '#call' do
    context 'when header X-Agouti-Enable is set' do
      context 'when header X-Agouti-Enable is set with 1' do
        context 'when the request response is not an html' do
          # behaviour: do nothing
          pending
        end
        context 'when header X-Agouti-Limit is not set' do
          # behaviour: returns the data gzipped truncated at 14000
          pending
        end
        context 'when header X-Agouti-Limit is set' do
          context 'when header X-Agouti-Limit is set with a valid number of bytes' do
            # behaviour: returns the data gzipped truncated at passed size
            pending
          end
          context 'when header X-Agouti-Limit is set with an invalid value' do
            # behaviour: raises an exception
            pending
          end
        end
      end
      context 'when header X-Agouti-Enable is set with 0' do
        # behaviour: do nothing
        pending
      end
      context 'when header X-Agouti-Enable is set with an invalid value' do
        # behaviour: raises an exception
        pending
      end
    end
    context 'when header X-Agouti-Enable is not set' do
      # behaviour: do nothing
      pending
    end
  end
end