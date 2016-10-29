# lua-resty-ceph

A simple Lua wrapper for ceph with swift based on OpenResty.

More: 

1. <http://docs.ceph.org.cn/radosgw/s3/>
2. <http://docs.ceph.org.cn/radosgw/swift/>


# API

* [new](#new)
* [get_all_buckets](#get_all_buckets)
* [create_bucket](#create_bucket)
* [del_bucket](#del_bucket)
* [get_all_buckets](#get_all_buckets)
* [get_all_objs](#get_all_objs)
* [get_buckets_location](#get_buckets_location)
* [get_buckets_acl](#get_buckets_acl)
* [create_obj](#create_obj)
* [get_obj](#get_obj)
* [del_obj](#del_obj)
* [check_for_existance](#check_for_existance)
* [get_obj_acl](#get_obj_acl)
* [set_obj_acl](#set_obj_acl)


## Synopsis


# Usage

## new

    local app = cephs3:new(access_key, secret_key, auth_uri)

## get_all_buckets

    app:get_all_buckets()

## create_bucket

    app:create_bucket(bucket)

## del_bucket

    app:del_bucket(bucket)

## get_all_objs

    app:get_all_objs(bucket)

## set_bucket_acl

    app:set_bucket_acl(bucket)

## create_obj

    app:create_obj(bucket, file, content)

## get_obj

    app:get_obj(bucket, file)

## del_obj

    app:del_obj(bucket, file)


# TODO

* Upload operations.

# Author

Linsir: <https://github.com/linsir>


# Licence

BSD license.

All rights reserved.
