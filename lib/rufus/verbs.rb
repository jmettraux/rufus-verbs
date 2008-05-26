#
#--
# Copyright (c) 2008, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# (MIT license)
#++
#

#
# John Mettraux
#
# Made in Japan
#
# 2008/01/11
#

require 'rufus/verbs/endpoint'
require 'rufus/verbs/conditional'


module Rufus::Verbs


    #
    # GET
    #
    def get (*args)

        EndPoint.request :get, args
    end

    #
    # POST
    #
    def post (*args, &block)

        EndPoint.request :post, args, &block
    end

    #
    # PUT
    #
    def put (*args, &block)

        EndPoint.request :put, args, &block
    end

    #
    # DELETE
    #
    def delete (*args)

        EndPoint.request :delete, args
    end

    #
    # HEAD
    #
    def head (*args)

        EndPoint.request :head, args
    end

    #
    # OPTIONS
    #
    def options (*args)

        EndPoint.request :options, args
    end

    #
    # Opens a file or a URI (GETs it and return the reply). Will tolerate
    # a HTTP[S] URI or a file path.
    #
    # It is not named open() in order not to collide with File.open and
    # open-uri's open.
    #
    def fopen (uri, *args, &block)

        # should I really care about blocks here ? ...

        u = URI.parse uri.to_s

        return File.open(uri.to_s, &block) \
            if u.scheme == nil

        return File.open(uri.to_s[5..-1], &block) \
            if u.scheme == 'file'

        if u.scheme == 'http' or u.scheme == 'https'

            r = EndPoint.request(:get, [ uri ] + args) \

            if block
                block.call r
                return
            end

            class << r
                def read
                    self.body
                end
            end unless r.respond_to?(:read)

            return r
        end

        raise "can't handle scheme '#{u.scheme}' for #{u.to_s}"
    end

    extend self
end

